/// A sheet from the side of the screen, a popover under its button and a
/// card shown while a pointer rests on a link, painted on ui_core's side
/// sheet and anchored overlay.
library;

import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/kit_paint.dart';
import '../internal/sheet_header.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'icon_button.dart';
import 'sheet.dart';

/// A panel the full height of the screen, from its start or end edge: a
/// record's details beside a list, filters, settings, a phone's navigation.
/// The surface with a rim on its inner edge and the large shadow; its inner
/// corners take `shapes.large` (the outer ones stand on the screen's edge),
/// like the bottom sheet's drawer. A header prints [title] (and [subtitle]
/// as its pill) with a close button; [child] scrolls under it, and the
/// footer holds [leading] and [trailing] over a hairline.
///
/// Shown by [showMinimalSheet]; composed in a page it is a static panel.
/// [style] dresses it, over `components.bottomSheet`.
///
/// ```dart
/// showMinimalSheet<void>(context, title: 'Filters', builder: (context) => filters)
/// ```
class MinimalSheet extends StatelessWidget {
  /// A side panel holding [child].
  const MinimalSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.side = MinimalSide.end,
    this.leading,
    this.trailing,
    this.onClose,
    this.style,
  }) : assert(
         side == MinimalSide.start || side == MinimalSide.end,
         'a side sheet stands on the start or the end',
       );

  /// The content, scrolling under the header.
  final Widget child;

  /// What the sheet is.
  final String? title;

  /// What it acts in (a project, a team), the header's pill.
  final String? subtitle;

  /// The edge it stands on: [MinimalSide.start] or [MinimalSide.end].
  final MinimalSide side;

  /// The footer's secondary action.
  final MinimalSheetAction? leading;

  /// The footer's confirming action.
  final MinimalSheetAction? trailing;

  /// The close button's press; null pops the route it stands in.
  final VoidCallback? onClose;

  /// Its style, over `components.bottomSheet`.
  final MinimalStyle? style;

  /// [shape] with only the corners on the [onLeft] panel's inner edge.
  static OutlinedBorder _inner(OutlinedBorder shape, {required bool onLeft}) {
    BorderRadius keep(BorderRadiusGeometry r) {
      final c = r.resolve(TextDirection.ltr);
      return onLeft
          ? BorderRadius.only(topRight: c.topRight, bottomRight: c.bottomRight)
          : BorderRadius.only(topLeft: c.topLeft, bottomLeft: c.bottomLeft);
    }

    return switch (shape) {
      final RoundedRectangleBorder s => s.copyWith(
        borderRadius: keep(s.borderRadius),
      ),
      final BeveledRectangleBorder s => s.copyWith(
        borderRadius: keep(s.borderRadius),
      ),
      final ContinuousRectangleBorder s => s.copyWith(
        borderRadius: keep(s.borderRadius),
      ),
      final RoundedSuperellipseBorder s => s.copyWith(
        borderRadius: keep(s.borderRadius),
      ),
      _ => const RoundedRectangleBorder(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final so = MinimalStyleOf([style, t.components.bottomSheet], const {});
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final onLeft = (side == MinimalSide.start) != rtl;
    final shape = _inner(so.shape ?? t.shapes.large, onLeft: onLeft);
    final leading = this.leading;
    final trailing = this.trailing;
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: minimalFrame(
          shape,
          fill: so.fill ?? t.card,
          side: so.rim(t.border, t.rim),
          shadows: t.shadowLg,
        ),
        child: minimalClip(
          shape,
          child: SafeArea(
            left: onLeft,
            right: !onLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MinimalGap(MinimalSpacing.s4),
                MinimalSheetHeader(
                  title: title,
                  scope: subtitle,
                  close: MinimalIconButton(
                    LucideIcons.x,
                    label: MinimalLocalizations.of(context).close,
                    variant: MinimalIconButtonVariant.ghost,
                    onPressed:
                        onClose ?? () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MinimalChromeMetrics.sheetPad,
                    ),
                    child: child,
                  ),
                ),
                if (leading != null || trailing != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(
                      MinimalChromeMetrics.sheetPad,
                      MinimalSpacing.s12,
                      MinimalChromeMetrics.sheetPad,
                      MinimalSpacing.s12,
                    ),
                    padding: const EdgeInsets.only(top: MinimalSpacing.s12),
                    decoration: BoxDecoration(border: Border(top: t.rule)),
                    child: MinimalSheetFooter(
                      leading: leading,
                      trailing: trailing,
                    ),
                  )
                else
                  const MinimalGap(MinimalChromeMetrics.sheetPad),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a [MinimalSheet] from [side] over the whole app, on a dimmed page:
/// it slides in (fades, under Reduce Motion), focus moves into it and back
/// to the opener when it closes; Escape, a tap on the scrim, a drag toward
/// its edge or its close button closes it. [width] is its width, at most
/// the screen less 56 px. The behaviour is ui_core's
/// ([DesignSideSheetRoute]); Minimal paints it.
///
/// ```dart
/// await showMinimalSheet<void>(context, title: 'Order #1042', builder: (context) => details, trailing: MinimalSheetAction('Refund', onPressed: refund));
/// ```
Future<T?> showMinimalSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  String? subtitle,
  MinimalSide side = MinimalSide.end,
  double width = 380,
  MinimalSheetAction? leading,
  MinimalSheetAction? trailing,
  MinimalStyle? style,
}) {
  assert(
    side == MinimalSide.start || side == MinimalSide.end,
    'a side sheet comes from the start or the end',
  );
  final t = context.minimalTheme;
  final words = MinimalLocalizations.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    DesignSideSheetRoute<T>(
      edge: side == MinimalSide.start
          ? DesignSheetEdge.start
          : DesignSheetEdge.end,
      width: width,
      barrierColor: t.overlay,
      barrierLabel: words.close,
      semanticLabel: title,
      transitionDuration: MinimalChromeMetrics.sheetIn,
      builder: (context, sheet) => MinimalSheet(
        title: title,
        subtitle: subtitle,
        side: side,
        leading: leading,
        trailing: trailing,
        onClose: sheet.close,
        style: style,
        child: Builder(builder: builder),
      ),
    ),
  );
}

/// A side, as shadcn's `side`: where a [MinimalPopover] or
/// [MinimalHoverCard] opens beside its anchor, and which edge of the screen
/// a side sheet comes from (the start or the end).
enum MinimalSide {
  /// Over it.
  top,

  /// Under it (over it when there is no room).
  bottom,

  /// Before it in reading order (left in English).
  start,

  /// After it in reading order.
  end,
}

DesignOverlaySide _side(MinimalSide side) => switch (side) {
  MinimalSide.bottom => DesignOverlaySide.below,
  MinimalSide.top => DesignOverlaySide.above,
  MinimalSide.start => DesignOverlaySide.start,
  MinimalSide.end => DesignOverlaySide.end,
};

/// A small card a button opens beside itself: a filter's options, a date
/// and its note, a share link, a short form. Minimal's floating panel (the
/// surface on `components.menu`'s shape, else `shapes.medium`, with the
/// rim and the menu's shadow), [width] wide, padded 12 px; it fades in and
/// slides 4 px from its anchor.
///
/// [anchor] paints the button: give its press `toggle`, and `open` to
/// whatever shows it open. Focus moves into the card and Tab stays there;
/// Escape or a tap outside closes it and focus goes back to the button.
/// [content] gets a `close` for a Done or Apply inside. The behaviour is
/// ui_core's ([DesignAnchoredOverlay]); Minimal paints it.
///
/// ```dart
/// MinimalPopover(anchor: (context, toggle, open) => MinimalButton('Filters', variant: MinimalButtonVariant.secondary, onPressed: toggle), content: (context, close) => filters)
/// ```
class MinimalPopover extends StatelessWidget {
  /// A popover opened from [anchor].
  const MinimalPopover({
    super.key,
    required this.anchor,
    required this.content,
    this.side = MinimalSide.bottom,
    this.width = 280,
    this.label,
    this.style,
  });

  /// Paints the button that opens it.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  anchor;

  /// Paints the card's content; `close` closes it.
  final Widget Function(BuildContext context, VoidCallback close) content;

  /// Where it opens.
  final MinimalSide side;

  /// The card's width.
  final double width;

  /// What a screen reader calls the card.
  final String? label;

  /// The card's style, over `components.menu`.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    // The card keeps its own [width], whatever opens it.
    placement: DesignOverlayPlacement(
      side: _side(side),
      gap: 6,
      matchAnchorWidth: false,
    ),
    semanticLabel: label,
    anchorBuilder: (context, a) => anchor(context, a.toggle, a.isOpen),
    overlayBuilder: (context, info) => minimalKitPresence(
      context,
      info,
      MinimalKitPanel(
        style: style,
        width: width,
        maxHeight: info.maxSize.height,
        padding: const EdgeInsets.all(MinimalSpacing.s12),
        child: SingleChildScrollView(child: content(context, info.close)),
      ),
    ),
  );
}

/// A preview shown while a pointer rests on [child], or the keyboard is on
/// it: a person's card behind a name, a link's page, an issue's summary.
/// The same floating panel as [MinimalPopover], [width] wide, padded
/// 12 px; it opens after 0.7 s and stays while the pointer travels into
/// it. A long press opens it on touch.
///
/// It only previews: what it says must be reachable some other way (the
/// link's own page), and focus stays on [child]. The behaviour is ui_core's
/// ([DesignAnchoredOverlay], hover); Minimal paints it.
///
/// ```dart
/// MinimalHoverCard(card: personCard, child: MinimalLink('@ana', onPressed: openProfile))
/// ```
class MinimalHoverCard extends StatelessWidget {
  /// A hover card over [child].
  const MinimalHoverCard({
    super.key,
    required this.child,
    required this.card,
    this.side = MinimalSide.bottom,
    this.width = 280,
    this.style,
  });

  /// What it previews: a link, a name, an avatar.
  final Widget child;

  /// The preview.
  final Widget card;

  /// Where it opens.
  final MinimalSide side;

  /// Its width.
  final double width;

  /// Its style, over `components.menu`.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    trigger: DesignOverlayTrigger.hover,
    focusOnOpen: false,
    // The card keeps its own [width], whatever opens it.
    placement: DesignOverlayPlacement(
      side: _side(side),
      gap: 6,
      matchAnchorWidth: false,
    ),
    anchorBuilder: (context, a) => child,
    overlayBuilder: (context, info) => minimalKitPresence(
      context,
      info,
      MinimalKitPanel(
        style: style,
        width: width,
        maxHeight: info.maxSize.height,
        padding: const EdgeInsets.all(MinimalSpacing.s12),
        child: card,
      ),
    ),
  );
}
