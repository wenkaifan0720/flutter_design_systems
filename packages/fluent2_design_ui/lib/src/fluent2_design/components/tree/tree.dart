import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/well.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// A tree's size, Fluent's `size`: [small] items 24 tall in caption1,
/// [medium] 32 in body1 (the default). On a phone every item keeps 44.
enum Fluent2TreeSize {
  /// The small size.
  small,

  /// The medium size.
  medium,
}

/// One item of a [Fluent2Tree]: its [value], its [label], a glyph before it
/// ([icon], [openIcon] while its branch is open), a quiet [aside] at its end
/// (a count) and the items under it ([children]); with children it is a
/// branch.
///
/// ```dart
/// Fluent2TreeItem('design', 'Design', icon: Fluent2Icons.folder, openIcon: Fluent2Icons.folderFilled, children: [Fluent2TreeItem('brand', 'Brand guidelines.pdf', icon: Fluent2Icons.documentText)])
/// ```
@immutable
class Fluent2TreeItem<T> {
  /// A tree item for [value], labelled [label].
  const Fluent2TreeItem(
    this.value,
    this.label, {
    this.icon,
    this.openIcon,
    this.aside,
    this.children = const [],
  });

  /// The value the item stands for.
  final T value;

  /// The item's words.
  final String label;

  /// The glyph before [label]; null shows none.
  final IconData? icon;

  /// The glyph while its branch is open; null keeps [icon].
  final IconData? openIcon;

  /// A quiet word at the item's end (a count); null shows none.
  final String? aside;

  /// The items under it; with any it is a branch.
  final List<Fluent2TreeItem<T>> children;

  /// Whether it has items under it.
  bool get isBranch => children.isNotEmpty;
}

/// Fluent 2's Tree: nested [items] (a workspace's folders and files, a
/// channel list), each a row 32 tall (44 on a phone) on the subtle fill's
/// hover and pressed steps, indented 24 a level: a branch leads with its 12
/// chevron in a 24 column (turning down while open, `durationNormal`), a
/// leaf stands where the chevron would. A press on a branch opens or shuts
/// it; a press on a leaf asks [onChanged] for its value, and the item whose
/// value is [value] wears the subtle selected fill. Open branches are the
/// tree's own, from [initiallyOpen]. Read as items that say whether they are
/// expanded and which is selected.
///
/// ```dart
/// Fluent2Tree<String>(items: [Fluent2TreeItem('design', 'Design', children: [Fluent2TreeItem('brand', 'Brand guidelines.pdf')])], value: 'brand', initiallyExpanded: const {'design'}, onChanged: open)
/// ```
class Fluent2Tree<T> extends StatefulWidget {
  /// A tree of [items].
  const Fluent2Tree({
    required this.items,
    this.value,
    this.onChanged,
    this.initiallyExpanded,
    this.size = Fluent2TreeSize.medium,
    this.label,
    super.key,
  });

  /// The top-level items, in order.
  final List<Fluent2TreeItem<T>> items;

  /// The selected leaf's value.
  final T? value;

  /// Asked for a leaf's value when it is pressed; null draws the leaves
  /// inert.
  final ValueChanged<T>? onChanged;

  /// The branches open on the first frame.
  final Set<T>? initiallyExpanded;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2TreeSize size;

  /// What a screen reader calls the tree.
  final String? label;

  @override
  State<Fluent2Tree<T>> createState() => _Fluent2TreeState<T>();
}

// The tree's behaviour is the design kit's DesignTree: the arrows walk and open
// it, Home and End jump, Enter activates, Space selects, `*` opens a level, one
// row is the tab stop, and each row says its level, place, expanded and
// selected state. Fluent 2 paints the rows.
class _Fluent2TreeState<T> extends State<Fluent2Tree<T>> {
  late DesignTreeController<Fluent2TreeItem<T>> _tree = _controller(
    widget.initiallyExpanded ?? const {},
  );

  DesignTreeController<Fluent2TreeItem<T>> _controller(Set<T> open) {
    final expanded = <Fluent2TreeItem<T>>[];
    void walk(List<Fluent2TreeItem<T>> items) {
      for (final item in items) {
        if (item.isBranch && open.contains(item.value)) expanded.add(item);
        walk(item.children);
      }
    }

    walk(widget.items);
    return DesignTreeController<Fluent2TreeItem<T>>(
      roots: widget.items,
      childrenOf: (item) => item.children,
      expanded: expanded,
    );
  }

  // The values of the branches open now, so new items keep them open.
  Set<T> _openValues() {
    final open = <T>{};
    void walk(List<Fluent2TreeItem<T>> items) {
      for (final item in items) {
        if (_tree.isExpanded(item)) open.add(item.value);
        walk(item.children);
      }
    }

    walk(_tree.roots);
    return open;
  }

  @override
  void didUpdateWidget(Fluent2Tree<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      final old = _tree;
      _tree = _controller(_openValues());
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final change = widget.onChanged;
    return DesignTree<Fluent2TreeItem<T>>(
      controller: _tree,
      semanticLabel: widget.label,
      labelOf: (item) =>
          item.aside == null ? item.label : '${item.label}, ${item.aside}',
      onActivate: change == null
          ? null
          : (item) {
              if (!item.isBranch) change(item.value);
            },
      rowBuilder: (context, row) => Padding(
        padding: const EdgeInsets.only(bottom: Fluent2Spacing.xxs),
        child: _TreeRow<T>(
          item: row.row.node,
          depth: row.row.depth,
          open: row.expanded,
          selected:
              !row.row.node.isBranch && row.row.node.value == widget.value,
          inert: !row.row.node.isBranch && change == null,
          size: widget.size,
          states: row.states,
        ),
      ),
    );
  }
}

class _TreeRow<T> extends StatelessWidget {
  const _TreeRow({
    required this.item,
    required this.depth,
    required this.open,
    required this.selected,
    required this.inert,
    required this.size,
    required this.states,
  });

  final Fluent2TreeItem<T> item;
  final int depth;
  final bool open;
  final bool selected;

  /// A leaf no one listens to: drawn in the disabled ink.
  final bool inert;
  final Fluent2TreeSize size;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final wide = Fluent2Layout.isWide(context);
    final small = size == Fluent2TreeSize.small;
    final height = !wide || Fluent2Layout.padded(context)
        ? Fluent2Layout.hitTargetOf(context)
        : small
        ? 24.0
        : 32.0;
    final type = small ? t.caption1 : t.body1;
    final duration = Fluent2Motion.on(context)
        ? Fluent2Motion.normal
        : Duration.zero;
    final aside = item.aside;
    final indent = (item.isBranch ? depth : depth + 1) * Fluent2Spacing.xxl;
    final press = inert ? Fluent2Press.disabled : states.press;
    final disabled = press == Fluent2Press.disabled;
    final ink = disabled
        ? t.textDisabled
        : selected
        ? t.colors.neutralForeground2Selected
        : press.pick(
            t.colors.neutralForeground2,
            t.colors.neutralForeground2Hover,
            t.colors.neutralForeground2Pressed,
          );
    final chevronInk = press.pick(
      t.colors.neutralForeground3,
      t.colors.neutralForeground3Hover,
      t.colors.neutralForeground3Pressed,
    );
    final fill = selected
        ? fluent2Step(t, t.colors.subtleBackgroundSelected)
        : disabled
        ? t.colors.subtleBackground
        : press.pick(
            t.colors.subtleBackground,
            t.colors.subtleBackgroundHover,
            t.colors.subtleBackgroundPressed,
          );
    final glyph = open ? (item.openIcon ?? item.icon) : item.icon;
    final face = Container(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsetsDirectional.only(start: indent),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Fluent2Radius.medium),
      ),
      child: Row(
        children: [
          if (item.isBranch)
            SizedBox(
              width: Fluent2Spacing.xxl,
              child: AnimatedRotation(
                // The mirrored glyph turns the other way right to left, so
                // an open branch points down either way.
                turns: open
                    ? (Directionality.of(context) == TextDirection.rtl
                          ? -0.25
                          : 0.25)
                    : 0,
                duration: duration,
                curve: Fluent2Motion.easyEaseMax,
                child: Icon(
                  Fluent2Icons.chevronRight12,
                  size: Fluent2IconSize.i12,
                  color: chevronInk,
                ),
              ),
            ),
          if (glyph != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Fluent2Spacing.xs),
              child: Icon(glyph, size: Fluent2IconSize.i20, color: ink),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Fluent2Spacing.xxs,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (selected ? type.strong : type).c(ink),
              ),
            ),
          ),
          if (aside != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Fluent2Spacing.m),
              child: Text(
                aside,
                maxLines: 1,
                style: t.caption1.c(t.textTertiary),
              ),
            ),
        ],
      ),
    );
    if (!states.focused) return face;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        face,
        const Positioned.fill(
          child: IgnorePointer(
            child: Fluent2FocusRing(radius: Fluent2Radius.medium),
          ),
        ),
      ],
    );
  }
}
