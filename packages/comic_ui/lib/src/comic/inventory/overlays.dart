// The raised rows the shared inventory adds: a side sheet, a popover and a hover card. The design kit runs
// the route and the anchoring; each surface is a Comic panel, inked in the shape family's corners.
import 'package:ui_core/ui_core.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../controls.dart';
import '../glyphs.dart';
import '../layout.dart';
import '../raised.dart';
import '../rows.dart';
import '../styled.dart';
import '../theme.dart';

/// Raises [builder]'s [ComicSheet] from the screen's side: the end edge unless [edge] says otherwise. A tap on the
/// scrim or a drag toward the edge closes it. Completes with what the sheet popped.
///
/// ```dart
/// showComicSheet(context, builder: (_) => const ComicSheet(title: 'Filters', child: Text('Only unread')))
/// ```
Future<T?> showComicSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  DesignSheetEdge edge = DesignSheetEdge.end,
  double width = 384,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  String? closeLabel,
  String? label,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final carry = comicCarryTo(context, navigator);
  return navigator.push<T>(
    DesignSideSheetRoute<T>(
      edge: edge,
      width: width,
      barrierDismissible: barrierDismissible,
      barrierColor: ComicTheme.of(context).colors.scrim,
      barrierLabel:
          closeLabel ?? DesignLocalizations.of(context).closeButtonLabel,
      semanticLabel: label,
      builder: (context, sheet) => carry(context, Builder(builder: builder)),
    ),
  );
}

/// The inked panel a side sheet holds: a title and a close at its head, words that scroll, and actions along its foot.
/// It stands clear of the screen's edges so every corner of the shape family shows.
///
/// ```dart
/// ComicSheet(title: 'Filters', child: Text('Only unread'))
/// ```
class ComicSheet extends StatelessWidget {
  /// Creates a side sheet's face.
  const ComicSheet({
    super.key,
    this.style,
    this.title,
    required this.child,
    this.actions = const [],
    this.onClose,
    this.closeLabel,
    this.showClose = true,
  });

  /// The sheet's name, read as the route's name.
  final String? title;

  /// What the sheet says; it scrolls past the screen.
  final Widget child;

  /// Buttons along the foot.
  final List<Widget> actions;

  /// What the close does; null pops the route.
  final VoidCallback? onClose;

  /// What a screen reader calls the close.
  final String? closeLabel;

  /// Whether the close shows when [onClose] is null.
  final bool showClose;

  /// Appearance above the component theme.
  final ComicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final look = ComicStyleOf([style, t.sheetTheme], const {});
    final rim = comicRim(t, look, t.colors.nightLine, 3);
    final shape = (look.shape ?? t.shapes.large).copyWith(side: rim);
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: look.fill ?? t.colors.card,
            shape: shape,
          ),
          child: Padding(
            padding: shape.dimensions.add(EdgeInsets.all(rim.width + 6)),
            child: LayoutBuilder(
              builder: (context, box) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null || onClose != null || showClose)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        8,
                        8,
                        8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: title == null
                                ? const SizedBox.shrink()
                                : Semantics(
                                    header: true,
                                    namesRoute: true,
                                    child: Text(title!, style: t.type.panel),
                                  ),
                          ),
                          if (onClose != null || showClose)
                            ComicIconButton(
                              ComicGlyphs.close,
                              label:
                                  closeLabel ??
                                  DesignLocalizations.of(context)
                                      .closeButtonLabel,
                              onPressed:
                                  onClose ??
                                  () => Navigator.of(context).maybePop(),
                            ),
                        ],
                      ),
                    ),
                  if (box.hasBoundedHeight)
                    Flexible(
                      fit: box.hasTightHeight ? FlexFit.tight : FlexFit.loose,
                      child: body,
                    )
                  else
                    body,
                  if (actions.isNotEmpty)
                    ComicRuled(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: ComicColumn(
                          gap: 8,
                          skipEmpty: true,
                          children: actions,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _panel(
  DesignOverlayInfo info,
  double width,
  EdgeInsetsGeometry padding,
  Widget child,
) => ScaleTransition(
  // A short pop from its top, opaque from the first frame: nothing fades (law 6).
  scale: Tween<double>(begin: .92, end: 1).animate(info.animation),
  alignment: Alignment.topCenter,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: info.maxSize.height,
      maxWidth: math.min(width, info.maxSize.width),
    ),
    child: ComicRaisedFrame(
      padding: padding,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

/// A small raised panel that opens from whatever [anchorBuilder] draws, pressed: a filter, a colour, a few settings.
/// Press its anchor again, press away or Escape to close it. For a list of commands use a menu; for a modal question, a
/// dialog.
///
/// ```dart
/// ComicPopover(anchorBuilder: (context, a) => ComicButton('Filter', onPressed: a.toggle), builder: (context, close) => Text('Only unread'))
/// ```
class ComicPopover extends StatelessWidget {
  /// Creates a [ComicPopover].
  const ComicPopover({
    super.key,
    required this.anchorBuilder,
    required this.builder,
    this.side = DesignOverlaySide.below,
    this.align = DesignOverlayAlign.start,
    this.width = 320,
    this.label,
    this.controller,
    this.onOpenChanged,
  });

  /// Draws what opens it: call the anchor's `toggle` when pressed.
  final Widget Function(BuildContext context, DesignOverlayAnchor anchor)
  anchorBuilder;

  /// Draws what the panel holds; `close` closes it.
  final Widget Function(BuildContext context, VoidCallback close) builder;

  /// Which side of the anchor it opens on, room allowing.
  final DesignOverlaySide side;

  /// How it lines up with the anchor.
  final DesignOverlayAlign align;

  /// The panel's greatest width.
  final double width;

  /// What a screen reader calls the panel.
  final String? label;

  /// Opens and closes it from elsewhere.
  final MenuController? controller;

  /// Told when it opens and closes.
  final ValueChanged<bool>? onOpenChanged;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    controller: controller,
    onOpenChanged: onOpenChanged,
    semanticLabel: label,
    // A panel of its own width ([width]), not a list: it does not take a wide anchor's width.
    placement: DesignOverlayPlacement(
      side: side,
      align: align,
      gap: 8,
      matchAnchorWidth: false,
    ),
    anchorBuilder: anchorBuilder,
    overlayBuilder: (context, info) => _panel(
      info,
      width,
      const EdgeInsets.all(14),
      builder(context, info.close),
    ),
  );
}

/// A card that comes up while the pointer rests on [child], or the keyboard is on it, and goes when it leaves: more
/// about a name, without a press. What it says must also be reachable some other way; touch gets it on a long press.
///
/// ```dart
/// ComicHoverCard(card: Text('Inker, issue 12 on'), child: ComicLink('Ada', onPressed: open))
/// ```
class ComicHoverCard extends StatelessWidget {
  /// Creates a [ComicHoverCard].
  const ComicHoverCard({
    super.key,
    required this.child,
    required this.card,
    this.side = DesignOverlaySide.below,
    this.align = DesignOverlayAlign.start,
    this.width = 280,
    this.label,
  });

  /// What the pointer rests on.
  final Widget child;

  /// What comes up.
  final Widget card;

  /// Which side of [child] it comes up on, room allowing.
  final DesignOverlaySide side;

  /// How it lines up with [child].
  final DesignOverlayAlign align;

  /// The card's greatest width.
  final double width;

  /// What a screen reader calls the card.
  final String? label;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    trigger: DesignOverlayTrigger.hover,
    focusOnOpen: false,
    semanticLabel: label,
    // A panel of its own width ([width]), not a list: it does not take a wide anchor's width.
    placement: DesignOverlayPlacement(
      side: side,
      align: align,
      gap: 8,
      matchAnchorWidth: false,
    ),
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) =>
        _panel(info, width, const EdgeInsets.all(14), card),
  );
}
