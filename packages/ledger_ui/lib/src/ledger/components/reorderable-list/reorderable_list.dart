/// A list the reader puts in order by a grip at each line's end, on ui_core's
/// reorderable list.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme.dart';

/// A list the reader puts in order (the accounts on Home, a budget's
/// categories): each line ruled under, [itemBuilder]'s content beside a
/// grip at its end. A press on the grip, or a long press anywhere on the
/// line, lifts it on paper with the menu's shadow, the others making room
/// in Ledger's one motion as it is dragged. A screen reader offers Move up
/// and Move down on each line and hears where it landed. The list is only
/// as tall as its lines: put it in the page's scroll.
///
/// ```dart
/// LedgerReorderableList<String>(items: names, labelOf: (n) => n, onReorder: (from, to) => setState(() => names.insert(to, names.removeAt(from))), itemBuilder: (context, n) => Text(n))
/// ```
class LedgerReorderableList<T extends Object> extends StatelessWidget {
  /// [items] in order, each drawn by [itemBuilder].
  const LedgerReorderableList({
    required this.items,
    required this.onReorder,
    required this.labelOf,
    required this.itemBuilder,
    this.keyOf,
    super.key,
  });

  /// The items, in order.
  final List<T> items;

  /// Moves the item at `from` to `to` (both counted before the move).
  final void Function(int from, int to) onReorder;

  /// What a screen reader calls an item.
  final String Function(T item) labelOf;

  /// A line's content, beside its grip.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Tells items apart across moves; null: the item itself.
  final Object Function(T item)? keyOf;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('onReorder', onReorder));
    properties.add(ObjectFlagProperty<Object?>.has('labelOf', labelOf));
    properties.add(ObjectFlagProperty<Object?>.has('itemBuilder', itemBuilder));
    properties.add(ObjectFlagProperty<Object?>.has('keyOf', keyOf));
    properties.add(IterableProperty<T>('items', items));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return DesignReorderableList<T>(
      items: items,
      onReorder: onReorder,
      labelOf: labelOf,
      keyOf: keyOf,
      shrinkWrap: true,
      itemBuilder: (context, item, reorder) => DecoratedBox(
        decoration: BoxDecoration(
          color: t.background,
          border: Border(bottom: BorderSide(color: t.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: LedgerSpacing.s12,
                ),
                child: itemBuilder(context, item),
              ),
            ),
            reorder.handle(
              DesignTapTarget(
                alignment: AlignmentDirectional.centerEnd,
                child: Icon(
                  LucideIcons.gripVertical,
                  size: LedgerIconSize.i18,
                  color: t.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
      proxyDecorator: (child, index, animation) => DecoratedBox(
        decoration: BoxDecoration(color: t.surface, boxShadow: t.menuShadow),
        child: child,
      ),
    );
  }
}
