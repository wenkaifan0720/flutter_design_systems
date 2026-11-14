// What an Retro Desktop field shows while you edit in it, in place of Material's: the selection handles (a square on a stem in the
// act edge) and the menu over a selection (a bevelled strip on a phone, a card of rows by a desktop's pointer). The field
// itself is Flutter's, and so are its gestures, autofill, IME and semantics.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'behavior.dart';
import 'localizations.dart';
import 'press.dart';
import 'theme.dart';

/// Whether [platform] edits by touch: handles and a menu over the selection, rather than a pointer's right-click menu.
bool retroDesktopTouchEditing(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.fuchsia ||
  TargetPlatform.iOS => true,
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => false,
};

/// Retro Desktop's selection handles: a square on a stem in the act edge, under the selection's ends. On a desktop there are
/// none, as a pointer selects by dragging.
///
/// ```dart
/// TextField(selectionControls: RetroDesktopTextSelectionControls.of(Theme.of(context).platform))
/// ```
class RetroDesktopTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  RetroDesktopTextSelectionControls._(this._touch);

  /// The handles a phone or a tablet draws.
  static final RetroDesktopTextSelectionControls touch =
      RetroDesktopTextSelectionControls._(true);

  /// A desktop's: none.
  static final RetroDesktopTextSelectionControls desktop =
      RetroDesktopTextSelectionControls._(false);

  /// The controls for [platform].
  static RetroDesktopTextSelectionControls of(TargetPlatform platform) =>
      retroDesktopTouchEditing(platform) ? touch : desktop;

  /// A pixel-framed editing lens on touch platforms, using Flutter's gestures.
  static TextMagnifierConfiguration magnifier(BuildContext context) {
    if (!retroDesktopTouchEditing(Theme.of(context).platform)) {
      return TextMagnifierConfiguration.disabled;
    }
    final theme = RetroDesktopTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TextMagnifierConfiguration(
      shouldDisplayHandlesInMagnifier: false,
      magnifierBuilder: (_, _, info) => _RetroDesktopMagnifier(
        info: info,
        theme: theme,
        reduceMotion: reduceMotion,
      ),
    );
  }

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
    final color = RetroDesktopTheme.of(context).colors.control;
    // The overlay that stands it takes the drags and taps, as it does Material's.
    return SizedBox.square(
      dimension: _side,
      child: CustomPaint(
        painter: _HandlePainter(
          color,
          RetroDesktopTheme.of(context).shapes.small,
        ),
      ),
    );
  }
}

class _RetroDesktopMagnifier extends StatelessWidget {
  const _RetroDesktopMagnifier({
    required this.info,
    required this.theme,
    required this.reduceMotion,
  });
  final ValueNotifier<MagnifierInfo> info;
  final RetroDesktopThemeData theme;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MagnifierInfo>(
    valueListenable: info,
    builder: (context, value, _) {
      final media = MediaQuery.of(context);
      final safe = Rect.fromLTRB(
        media.padding.left + 8,
        media.padding.top + 8,
        media.size.width - media.padding.right - 8,
        media.size.height - media.padding.bottom - media.viewInsets.bottom - 8,
      );
      final width = math.min(112.0, math.max(0.0, safe.width));
      final height = math.min(48.0, math.max(0.0, safe.height));
      if (width == 0 || height == 0) return const SizedBox.shrink();
      if (value.fieldBounds.isEmpty) return const SizedBox.shrink();
      final visibleLine = value.currentLineBoundaries.intersect(
        value.fieldBounds,
      );
      final visibleCaret = value.caretRect.intersect(value.fieldBounds);
      final line = !visibleLine.isEmpty
          ? visibleLine
          : !visibleCaret.isEmpty
          ? visibleCaret
          : value.fieldBounds;
      final target = Offset(
        value.globalGesturePosition.dx.clamp(line.left, line.right).toDouble(),
        value.caretRect.center.dy
            .clamp(value.fieldBounds.top, value.fieldBounds.bottom)
            .toDouble(),
      );
      final ratio = media.devicePixelRatio;
      double snap(double value) => (value * ratio).round() / ratio;
      final left = snap(target.dx - width / 2)
          .clamp(safe.left, safe.right - width)
          .toDouble();
      final top = snap(line.top - height - 10)
          .clamp(safe.top, safe.bottom - height)
          .toDouble();
      final side =
          theme.menuTheme.side?.resolve(const {}) ??
          BorderSide(
            color:
                theme.menuTheme.edge?.resolve(const {}) ?? theme.colors.control,
            width: theme.strokes.regular / ratio,
          );
      final shape =
          theme.menuTheme.shape?.resolve(const {}) ?? theme.shapes.small;
      return AnimatedPositioned(
        left: left,
        top: top,
        duration: RetroDesktopMotion.durationOf(
          context,
          reduceMotion ? Duration.zero : theme.motion.move,
        ),
        curve: theme.motion.standard,
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RawMagnifier(
              size: Size(width, height),
              magnificationScale: 1.25,
              focalPointOffset:
                  target - Offset(left + width / 2, top + height / 2),
              clipBehavior: Clip.hardEdge,
              decoration: MagnifierDecoration(
                shape: shape.copyWith(side: side),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _HandlePainter extends CustomPainter {
  _HandlePainter(this.color, this.shape);
  final Color color;
  final OutlinedBorder shape;
  @override
  void paint(Canvas canvas, Size s) {
    final m = s.width / 2;
    canvas.drawRect(Rect.fromLTWH(m - 1, 0, 2, 8), Paint()..color = color);
    canvas.drawPath(
      shape.getOuterPath(Rect.fromLTWH(m - 6, 8, 12, 12)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_HandlePainter o) => o.color != color || o.shape != shape;
}

/// The menu over a selection: Cut, Copy, Paste, Select all and what else the platform offers, as a bevelled strip on a
/// phone and a card of rows by a desktop's pointer. Its words are `RetroDesktopLocalizations`'.
///
/// ```dart
/// TextField(contextMenuBuilder: RetroDesktopTextContextMenu.editable)
/// ```
class RetroDesktopTextContextMenu extends StatelessWidget {
  /// A menu of [buttonItems] at [anchors].
  const RetroDesktopTextContextMenu({
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
      forField(
        context,
        state.context,
        anchors: state.contextMenuAnchors,
        buttonItems: state.contextMenuButtonItems,
      );

  /// The menu for the field at [field], standing in the overlay at [context]:
  /// it keeps the field's type scale, motion, words and look.
  static Widget forField(
    BuildContext context,
    BuildContext field, {
    required TextSelectionToolbarAnchors anchors,
    required List<ContextMenuButtonItem> buttonItems,
  }) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: MediaQuery.textScalerOf(field),
      disableAnimations: MediaQuery.disableAnimationsOf(field),
    ),
    child: Localizations.override(
      context: field,
      child: InheritedTheme.captureAll(
        field,
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(field),
          child: RetroDesktopTextContextMenu(
            anchors: anchors,
            buttonItems: buttonItems,
          ),
        ),
      ),
    ),
  );

  /// The words for [item]: its own label, else the part's word for its kind.
  static String labelOf(BuildContext context, ContextMenuButtonItem item) {
    if (item.label != null) return item.label!;
    final w = RetroDesktopLocalizations.of(context);
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
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final touch = retroDesktopTouchEditing(Theme.of(context).platform);
    final items = [
      for (final item in buttonItems)
        RetroDesktopPressable(
          onPressed: item.onPressed,
          label: labelOf(context, item),
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
                child: ExcludeSemantics(
                  child: Text(
                    labelOf(context, item),
                    style: t.type.text(
                      13,
                      16,
                      weight: FontWeight.w500,
                      color: c.text,
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
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: c.platinum,
              shape: t.shapes.medium.copyWith(
                side: BorderSide(color: c.control, width: t.strokes.regular),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
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
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.platinum,
            shape: t.shapes.medium.copyWith(
              side: BorderSide(color: c.control, width: t.strokes.regular),
            ),
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
