// What an Neumorphism field shows while you edit in it, in place of Material's: the selection handles (a rounded drop on a stem in the
// ink) and the menu over a selection (a soft strip on a phone, a card of rows by a desktop's pointer). The field
// itself is Flutter's, and so are its gestures, autofill, IME and semantics.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/geometry.dart';
import 'localizations.dart';
import 'controls.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'theme.dart';

/// Whether [platform] edits by touch: handles and a menu over the selection, rather than a pointer's right-click menu.
bool neumorphicTouchEditing(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.fuchsia ||
  TargetPlatform.iOS => true,
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => false,
};

/// Neumorphism's selection handles: a rounded drop on a stem in the ink, under the selection's ends. On a desktop there are
/// none, as a pointer selects by dragging.
///
/// ```dart
/// TextField(selectionControls: NeumorphicTextSelectionControls.of(Theme.of(context).platform))
/// ```
class NeumorphicTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  NeumorphicTextSelectionControls._(this._touch);

  /// The handles a phone or a tablet draws.
  static final NeumorphicTextSelectionControls touch =
      NeumorphicTextSelectionControls._(true);

  /// A desktop's: none.
  static final NeumorphicTextSelectionControls desktop =
      NeumorphicTextSelectionControls._(false);

  /// The controls for [platform].
  static NeumorphicTextSelectionControls of(TargetPlatform platform) =>
      neumorphicTouchEditing(platform) ? touch : desktop;

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
    final color = NeumorphicTheme.of(context).colors.ink;
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
    canvas.drawLine(
      Offset(m, 0),
      Offset(m, 8),
      neumorphicStrokePaint(color, 2),
    );
    canvas.drawCircle(Offset(m, 14), 6, neumorphicFillPaint(color));
  }

  @override
  bool shouldRepaint(_HandlePainter o) => o.color != color;
}

// Flutter's touch delegate places a toolbar below its selection when it cannot
// fit above, even if a tall menu then extends off-screen. Keep the scrollable
// menu within the safe viewport while retaining its normal anchor placement.
class _SelectionLayout extends TextSelectionToolbarLayoutDelegate {
  _SelectionLayout({required super.anchorAbove, required super.anchorBelow});

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final at = super.getPositionForChild(size, childSize);
    return Offset(
      at.dx.clamp(0.0, math.max(0.0, size.width - childSize.width)),
      at.dy.clamp(0.0, math.max(0.0, size.height - childSize.height)),
    );
  }
}

/// The menu over a selection: Cut, Copy, Paste, Select all and what else the platform offers, as a soft strip on a
/// phone and a card of rows by a desktop's pointer. Its words are `NeumorphicLocalizations`'.
///
/// ```dart
/// TextField(contextMenuBuilder: NeumorphicTextContextMenu.editable)
/// ```
class NeumorphicTextContextMenu extends StatelessWidget {
  /// A menu of [buttonItems] at [anchors].
  const NeumorphicTextContextMenu({
    super.key,
    required this.anchors,
    required this.buttonItems,
    this.style,
  });

  /// Selection-menu styling before menuTheme.
  final NeumorphicStyle? style;

  /// Where the selection is: the menu stands above it, or below when there is no room.
  final TextSelectionToolbarAnchors anchors;

  /// What the menu offers.
  final List<ContextMenuButtonItem> buttonItems;

  /// The menu for [state]'s selection: `EditableText.contextMenuBuilder`.
  static Widget editable(BuildContext context, EditableTextState state) =>
      NeumorphicTextContextMenu(
        anchors: state.contextMenuAnchors,
        buttonItems: state.contextMenuButtonItems,
      );

  /// The words for [item]: its own label, else the part's word for its kind.
  static String labelOf(BuildContext context, ContextMenuButtonItem item) {
    if (item.label != null) return item.label!;
    final w = NeumorphicLocalizations.of(context);
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
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final touch = neumorphicTouchEditing(defaultTargetPlatform);
    final look = NeumorphicStyleOf([style, t.menuTheme], const {});
    final shape = look.shape;
    final border = (shape ?? t.shapes.corner(NeumorphicRadii.control)).copyWith(
      side:
          look.side ??
          (look.edge != null || t.highContrast
              ? BorderSide(
                  color: look.edge ?? c.edge,
                  width: neumorphicEdgeWidth,
                )
              : BorderSide.none),
    );
    Widget frame(Widget child) => DecoratedBox(
      decoration: ShapeDecoration(
        color: look.fill ?? c.ground,
        shape: border,
        shadows: [
          BoxShadow(
            color: c.highlight,
            offset: const Offset(-3, -3),
            blurRadius: 10,
          ),
          BoxShadow(
            color: c.shadow,
            offset: const Offset(4, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: look.minimumSize?.width ?? 0,
          minHeight: look.minimumSize?.height ?? 0,
        ),
        child: Padding(
          padding:
              (look.padding(Directionality.of(context)) ?? EdgeInsets.zero) +
              (shape?.dimensions.resolve(Directionality.of(context)) ??
                  EdgeInsets.zero),
          child: child,
        ),
      ),
    );
    final items = [
      for (final item in buttonItems)
        NeumorphicTap(
          onPressed: item.onPressed,
          label: labelOf(context, item),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: t.density.padding(
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Align(
                alignment: touch
                    ? Alignment.center
                    : AlignmentDirectional.centerStart,
                widthFactor: 1,
                heightFactor: 1,
                child: ExcludeSemantics(
                  child: Text(
                    labelOf(context, item),
                    style: t.textTheme.caption
                        .merge(look.textStyle)
                        .copyWith(color: look.foreground ?? c.ink),
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
          delegate: _SelectionLayout(
            anchorAbove: anchors.primaryAnchor - shift - const Offset(0, gap),
            anchorBelow:
                (anchors.secondaryAnchor ?? anchors.primaryAnchor) -
                shift +
                const Offset(0, gap),
          ),
          child: frame(SingleChildScrollView(child: Wrap(children: items))),
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
        child: frame(
          SingleChildScrollView(
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
