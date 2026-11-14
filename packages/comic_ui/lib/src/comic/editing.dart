// What an Comic field shows while you edit in it, in place of Material's: the selection handles (a square ink mark on a stem) and the menu over a selection (an inked caption on a phone, a card of rows by a desktop's pointer). The field
// itself is Flutter's, and so are its gestures, autofill, IME and semantics.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/geometry.dart';
import 'localizations.dart';
import 'press.dart';
import 'theme.dart';

/// Whether [platform] edits by touch: handles and a menu over the selection, rather than a pointer's right-click menu.
bool comicTouchEditing(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.fuchsia ||
  TargetPlatform.iOS => true,
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => false,
};

/// Comic's selection handles: a square ink mark on a stem, under the selection's ends. On a desktop there are
/// none, as a pointer selects by dragging.
///
/// ```dart
/// TextField(selectionControls: ComicTextSelectionControls.of(Theme.of(context).platform))
/// ```
class ComicTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  ComicTextSelectionControls._(this._touch);

  /// The handles a phone or a tablet draws.
  static final ComicTextSelectionControls touch = ComicTextSelectionControls._(
    true,
  );

  /// A desktop's: none.
  static final ComicTextSelectionControls desktop =
      ComicTextSelectionControls._(false);

  /// The controls for [platform].
  static ComicTextSelectionControls of(TargetPlatform platform) =>
      comicTouchEditing(platform) ? touch : desktop;

  final bool _touch;
  static const double _side = 22;

  @override
  Size getHandleSize(double textLineHeight) =>
      _touch ? const Size(_side, _side) : Size.zero;

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      _touch ? const Offset(_side / 2, 0) : Offset.zero;

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    if (!_touch) return const SizedBox.shrink();
    final colors = ComicTheme.of(context).colors;
    final color = colors.dark ? colors.text : colors.onPaper;
    // The overlay that stands it takes the drags and taps, as it does Material's.
    return SizedBox.square(
      dimension: _side,
      child: CustomPaint(painter: _HandlePainter(color)),
    );
  }
}

class _HandlePainter extends CustomPainter {
  _HandlePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final m = s.width / 2;
    canvas.drawLine(Offset(m, 0), Offset(m, 8), strokePaint(color, 2));
    canvas.drawRect(Rect.fromLTWH(m - 6, 8, 12, 12), fillPaint(color));
  }

  @override
  bool shouldRepaint(_HandlePainter o) => o.color != color;
}

/// The menu over a selection: Cut, Copy, Paste, Select all and what else the platform offers, as an inked caption on a
/// phone and a card of rows by a desktop's pointer. Its words are `ComicLocalizations`'.
///
/// ```dart
/// TextField(contextMenuBuilder: ComicTextContextMenu.editable)
/// ```
class ComicTextContextMenu extends StatelessWidget {
  /// A menu of [buttonItems] at [anchors].
  const ComicTextContextMenu({
    super.key,
    required this.anchors,
    required this.buttonItems,
  });

  /// Where the selection is: the menu stands above it, or below when there is no room.
  final TextSelectionToolbarAnchors anchors;

  /// What the menu offers.
  final List<ContextMenuButtonItem> buttonItems;

  /// The menu for [state]'s selection: `EditableText.contextMenuBuilder`.
  static Widget editable(BuildContext context, EditableTextState state) =>
      ComicTextContextMenu(
        anchors: state.contextMenuAnchors,
        buttonItems: state.contextMenuButtonItems,
      );

  /// The words for [item]: its own label, else the part's word for its kind.
  static String labelOf(BuildContext context, ContextMenuButtonItem item) {
    if (item.label != null) return item.label!;
    final w = ComicLocalizations.of(context);
    return switch (item.type) {
      ContextMenuButtonType.cut => w.cut,
      ContextMenuButtonType.copy => w.copy,
      ContextMenuButtonType.paste => w.paste,
      ContextMenuButtonType.selectAll => w.selectAll,
      ContextMenuButtonType.delete => w.delete,
      ContextMenuButtonType.lookUp => w.lookUp,
      ContextMenuButtonType.searchWeb => w.searchWeb,
      ContextMenuButtonType.share => w.share,
      ContextMenuButtonType.liveTextInput => w.scanText,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (buttonItems.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final c = t.colors;
    final touch = comicTouchEditing(defaultTargetPlatform);
    final items = [
      for (final item in buttonItems)
        ComicPressable(
          onPressed: item.onPressed,
          label: labelOf(context, item),
          washColor: touch ? c.onPaper : c.text,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: touch
                    ? Alignment.center
                    : AlignmentDirectional.centerStart,
                widthFactor: 1,
                heightFactor: 1,
                child: ExcludeSemantics(
                  child: Text(
                    labelOf(context, item),
                    maxLines: 1,
                    style: t.type.text(
                      13,
                      1,
                      weight: FontWeight.w500,
                      color: touch ? c.onPaper : c.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    final padding = MediaQuery.paddingOf(context);
    if (touch) {
      const gap = 8.0;
      final above = padding.top + gap;
      final shift = Offset(gap, above);
      return Padding(
        padding: EdgeInsets.fromLTRB(gap, above, gap, gap),
        child: CustomSingleChildLayout(
          delegate: TextSelectionToolbarLayoutDelegate(
            anchorAbove: anchors.primaryAnchor - shift - const Offset(0, gap),
            anchorBelow:
                (anchors.secondaryAnchor ?? anchors.primaryAnchor) -
                shift +
                const Offset(0, gap),
          ),
          child: ComicStateDecoration(
            decoration: ShapeDecoration(
              color: c.dark ? c.card : c.control,
              shape: ComicTheme.of(context).shapes.medium
                  .copyWith(side: BorderSide(color: c.nightLine)),
            ),
            child: Wrap(children: items),
          ),
        ),
      );
    }
    final shift = Offset(padding.left, padding.top);
    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left, padding.top, 0, 0),
      child: CustomSingleChildLayout(
        delegate: DesktopTextSelectionToolbarLayoutDelegate(
          anchor: anchors.primaryAnchor - shift,
        ),
        child: ComicStateDecoration(
          decoration: ShapeDecoration(
            color: c.card,
            shape: ComicTheme.of(context).shapes.medium
                .copyWith(side: BorderSide(color: c.nightLine)),
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          ),
        ),
      ),
    );
  }
}
