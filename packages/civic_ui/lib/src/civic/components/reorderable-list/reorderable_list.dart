import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../link/link.dart';

/// A list a reader puts in order (the order to visit offices, the
/// documents to send first): [items] on a card, rules between them, each
/// with a grip at its start and "Move up" and "Move down" at its end.
///
/// Three ways to move one, and none is hidden: drag its grip; focus the
/// grip and press Alt with Up or Down; or press its worded "Move up" or
/// "Move down" (on a phone, under its words). A pointer over the grip
/// darkens it, a keyboard focus lays it on the yellow plate over the ink
/// bar, and the row being dragged stands on an ink edge. A screen reader
/// hears where it landed ("Proof of address, 2 of 4"). ui_core's
/// [DesignReorderableList], Civic's painting.
///
/// Reads [CivicStyle]'s fill (the card) and foreground (the grip, by
/// state): its `style:`, then [CivicThemeData.reorderableListStyle].
///
/// ```dart
/// CivicReorderableList<String>(
///   items: documents,
///   labelOf: (d) => d,
///   onReorder: (from, to) => setState(() {
///     documents.insert(to, documents.removeAt(from));
///   }),
/// )
/// ```
class CivicReorderableList<T extends Object> extends StatelessWidget {
  /// [items] in the reader's order.
  const CivicReorderableList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.labelOf,
    this.itemBuilder,
    this.keyOf,
    this.moveUpLabel = 'Move up',
    this.moveDownLabel = 'Move down',
    this.style,
  });

  /// The items, in order.
  final List<T> items;

  /// Called with an item's place `from` and its new place `to` (counted
  /// after it left).
  final void Function(int from, int to) onReorder;

  /// An item's words, for its row and for a screen reader.
  final String Function(T item) labelOf;

  /// An item's row content; null: its words.
  final Widget Function(BuildContext context, T item)? itemBuilder;

  /// An item's identity; null: the item.
  final Object Function(T item)? keyOf;

  /// The words that move an item up one.
  final String moveUpLabel;

  /// The words that move an item down one.
  final String moveDownLabel;

  /// Overrides for this list's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.reorderableListStyle], const {});
    return ClipRRect(
      borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
      child: ColoredBox(
        color: so.fill ?? t.background,
        child: DesignReorderableList<T>(
          items: items,
          onReorder: onReorder,
          labelOf: labelOf,
          keyOf: keyOf,
          shrinkWrap: true,
          proxyDecorator: (child, index, animation) => DecoratedBox(
            // The row in the reader's hand stands on an ink edge.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(
                color: t.textPrimary,
                width: CivicMetrics.edge,
              ),
            ),
            child: ColoredBox(color: so.fill ?? t.background, child: child),
          ),
          itemBuilder: (context, item, reorder) {
            final label = labelOf(item);
            final words =
                itemBuilder?.call(context, item) ??
                Text(label, style: text.body.copyWith(color: t.textPrimary));
            final moves = Wrap(
              spacing: CivicSpacing.s16,
              children: [
                CivicLink(
                  onPressed: reorder.moveUp,
                  semanticLabel: '$moveUpLabel: $label',
                  child: Text(moveUpLabel),
                ),
                CivicLink(
                  onPressed: reorder.moveDown,
                  semanticLabel: '$moveDownLabel: $label',
                  child: Text(moveDownLabel),
                ),
              ],
            );
            return DecoratedBox(
              decoration: BoxDecoration(
                border: reorder.index == 0
                    ? null
                    : Border(top: BorderSide(color: t.hairline)),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: CivicSpacing.s16,
                ),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final narrow = box.maxWidth < 480;
                    return Row(
                      crossAxisAlignment: narrow
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        reorder.handle(_Grip(label: label, style: style)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: CivicSpacing.s12,
                            ),
                            child: narrow
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: CivicSpacing.s4,
                                    children: [words, moves],
                                  )
                                : Row(
                                    spacing: CivicSpacing.s16,
                                    children: [
                                      Expanded(child: words),
                                      moves,
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('items', items.length))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The drag grip: six squares on a 48 by 48 target, darkening under a
/// pointer, on the yellow plate while the keyboard is on it.
class _Grip extends StatefulWidget {
  const _Grip({required this.label, required this.style});

  final String label;
  final CivicStyle? style;

  @override
  State<_Grip> createState() => _GripState();
}

class _GripState extends State<_Grip> {
  bool _over = false;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final focused = Focus.of(context).hasFocus;
    final states = {
      if (_over) WidgetState.hovered,
      if (focused) WidgetState.focused,
    };
    final so = DesignStyleOf([widget.style, t.reorderableListStyle], states);
    return Semantics(
      label: widget.label,
      hint: 'Drag, or press Alt with the up or down arrow, to move it',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _over = true),
        onExit: (_) => setState(() => _over = false),
        child: CivicSpringValue(
          value: _over ? 1 : 0,
          spring: CivicMotion.press,
          builder: (context, over, _) => CivicSpringValue(
            value: focused ? 1 : 0,
            spring: CivicMotion.focus,
            effects: true,
            builder: (context, focus, _) => SizedBox.square(
              dimension: CivicMetrics.controlHeight,
              child: Center(
                child: CustomPaint(
                  painter: CivicFacePainter(
                    fill: t.focus.withValues(alpha: 0),
                    edgeColor: t.onFocus,
                    edgeHeight: 0,
                    press: 0,
                    focus: focus,
                    focusColor: t.focus,
                    barColor: t.focusBar,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child: CustomPaint(
                      size: const Size(12, 16),
                      painter: _Dots(
                        Color.lerp(
                          Color.lerp(
                            so.foreground ?? t.textSecondary,
                            t.textPrimary,
                            over,
                          ),
                          t.onFocus,
                          focus,
                        )!,
                      ),
                    ),
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

class _Dots extends CustomPainter {
  const _Dots(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (final x in const [0.0, 8.0]) {
      for (final y in const [0.0, 6.0, 12.0]) {
        canvas.drawRect(Rect.fromLTWH(x, y, 4, 4), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Dots old) => old.color != color;
}
