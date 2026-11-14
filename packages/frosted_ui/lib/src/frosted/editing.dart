// What a Frosted field shows while you edit in it, in place of Material's:
// the selection handles (a bead of the accent on a stem) and the menu over a
// selection (a pane of frosted glass with a row of words on a phone, a column
// by a desktop's pointer). The field itself is Flutter's, and so are its
// gestures, autofill, IME and semantics.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'components/pressable/pressable.dart';
import 'localizations.dart';
import 'theme.dart';

/// Whether [platform] edits by touch: handles and a menu over the selection,
/// rather than a pointer's right-click menu.
bool frostedTouchEditing(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.fuchsia ||
  TargetPlatform.iOS => true,
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => false,
};

/// Frosted's selection handles: a bead of the accent on a hairline stem,
/// under the selection's ends. On a desktop there are none, as a pointer
/// selects by dragging.
///
/// ```dart
/// TextField(selectionControls: FrostedTextSelectionControls.of(defaultTargetPlatform))
/// ```
class FrostedTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  FrostedTextSelectionControls._(this._touch);

  /// The handles a phone or a tablet draws.
  static final FrostedTextSelectionControls touch =
      FrostedTextSelectionControls._(true);

  /// A desktop's: none.
  static final FrostedTextSelectionControls desktop =
      FrostedTextSelectionControls._(false);

  /// The controls for [platform].
  static FrostedTextSelectionControls of(TargetPlatform platform) =>
      frostedTouchEditing(platform) ? touch : desktop;

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
    final t = FrostedTheme.of(context);
    // The overlay that stands it takes the drags and taps, as it does
    // Material's.
    return SizedBox.square(
      dimension: _side,
      child: CustomPaint(
        painter: _HandlePainter(
          t.colorScheme.accent,
          t.colorScheme.surface,
          FrostedStrokes.regular,
        ),
      ),
    );
  }
}

class _HandlePainter extends CustomPainter {
  _HandlePainter(this.color, this.rim, this.stroke);

  final Color color;
  final Color rim;
  final double stroke;

  @override
  void paint(Canvas canvas, Size s) {
    final m = s.width / 2;
    final ink = Paint()
      ..color = color
      ..strokeWidth = stroke * 2
      ..isAntiAlias = true;
    canvas.drawLine(Offset(m, 0), Offset(m, 8), ink);
    canvas.drawCircle(Offset(m, 14), 7, Paint()..color = rim);
    canvas.drawCircle(Offset(m, 14), 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HandlePainter o) =>
      o.color != color || o.rim != rim || o.stroke != stroke;
}

/// The menu over a selection: Cut, Copy, Paste, Select all and what else
/// the platform offers, on a pane of frosted glass: a row of words over the
/// selection on a phone, a column of rows by a desktop's pointer. Its words
/// are [FrostedLocalizations]'.
///
/// ```dart
/// TextField(contextMenuBuilder: FrostedTextContextMenu.editable)
/// ```
class FrostedTextContextMenu extends StatelessWidget {
  /// A menu of [buttonItems] at [anchors].
  const FrostedTextContextMenu({
    super.key,
    required this.anchors,
    required this.buttonItems,
  });

  /// Where the selection is: the menu stands above it, or below when there
  /// is no room.
  final TextSelectionToolbarAnchors anchors;

  /// What the menu offers.
  final List<ContextMenuButtonItem> buttonItems;

  /// The menu for [state]'s selection: `EditableText.contextMenuBuilder`.
  static Widget editable(BuildContext context, EditableTextState state) =>
      FrostedTextContextMenu(
        anchors: state.contextMenuAnchors,
        buttonItems: state.contextMenuButtonItems,
      );

  /// The words for [item]: its own label, else the part's word for its kind.
  static String labelOf(BuildContext context, ContextMenuButtonItem item) {
    if (item.label != null) return item.label!;
    final w = FrostedLocalizations.of(context);
    return switch (item.type) {
      ContextMenuButtonType.cut => w.cut,
      ContextMenuButtonType.copy => w.copy,
      ContextMenuButtonType.paste => w.paste,
      ContextMenuButtonType.selectAll => w.selectAll,
      ContextMenuButtonType.delete => DesignLocalizations.of(
        context,
      ).deleteButtonTooltip,
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
    final t = FrostedTheme.of(context);
    final touch = frostedTouchEditing(defaultTargetPlatform);
    final items = [
      for (final item in buttonItems)
        FrostedPressable(
          onPressed: item.onPressed,
          label: labelOf(context, item),
          radius: FrostedCorners.r12,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: touch
                    ? Alignment.center
                    : AlignmentDirectional.centerStart,
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  labelOf(context, item),
                  maxLines: 1,
                  style: t.textTheme.labelLarge.copyWith(
                    color: t.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    final pane = DecoratedBox(
      decoration: ShapeDecoration(
        color: t.glass.menu,
        shadows: t.shadows.menu,
        shape: FrostedCorners.medium.copyWith(
          side: BorderSide(
            color: t.glass.menuEdge,
            width: FrostedStrokes.hairline,
          ),
        ),
      ),
      child: touch
          ? Wrap(children: items)
          : IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
    );
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
          child: pane,
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
        child: pane,
      ),
    );
  }
}
